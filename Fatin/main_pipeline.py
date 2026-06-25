# ============================================================
#  CVD Early Warning Patch — FULL PIPELINE
#  ESP32 → AI Model → Flask API → Flutter App
#  
#  Run this ONE file. It does everything:
#  1. Reads ESP32 data from Serial COM3
#  2. Runs AI model on each reading
#  3. Serves results to Flutter app via Flask API
#  4. Prints transparent explanation to console
# ============================================================

import serial
import numpy as np
import joblib
import threading
import time
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

# ─────────────────────────────────────────────────────────────
#  CONFIG — change these if needed
# ─────────────────────────────────────────────────────────────
SERIAL_PORT   = 'COM3'      # Change to your ESP32 port
BAUD_RATE     = 115200
FLASK_HOST    = '0.0.0.0'  # 0.0.0.0 = accessible from phone on same WiFi
FLASK_PORT    = 5000
MODEL_PATH = r'C:\Users\Perehan sewid\Downloads\cvd_model.pkl'
# ─────────────────────────────────────────────────────────────
#  LOAD AI MODEL
# ─────────────────────────────────────────────────────────────
print("=" * 55)
print("  CVD Early Warning Patch — Full Pipeline")
print("=" * 55)
print("\n[1/3] Loading AI model...")

try:
    pkg            = joblib.load(MODEL_PATH)
    model          = pkg['model']
    feature_cols   = pkg['feature_cols']
    label_names    = pkg['label_names']
    phase_names    = pkg['phase_names']
    phase_hr_norms = pkg['phase_hr_norms']
    phase_temp_norms = pkg['phase_temp_norms']
    print(f"  ✅ Model loaded | CV Score: {pkg['cv_score']:.3f}")
    print(f"  Datasets: {', '.join(pkg['datasets_used'])}\n")
except FileNotFoundError:
    print("  ❌ cvd_model.pkl not found!")
    print("  Run train_model.py first, then come back.\n")
    exit()

# ─────────────────────────────────────────────────────────────
#  SHARED STATE (thread-safe between serial reader & Flask)
# ─────────────────────────────────────────────────────────────
latest_result = {
    'status': 'waiting',
    'message': 'Waiting for ESP32 data...'
}
result_lock = threading.Lock()

# ─────────────────────────────────────────────────────────────
#  FEATURE ENGINEERING
#  Must match train_model.py exactly — no GSR/stress sensor
# ─────────────────────────────────────────────────────────────
def build_features(hr, spo2, temp, motion,
                   cycle_phase, is_pregnant, menopausal, age):
    stress = 0.0  # GSR removed

    hr_phase_dev   = abs(hr - phase_hr_norms.get(int(cycle_phase), 72))
    temp_phase_dev = abs(temp - phase_temp_norms.get(int(cycle_phase), 36.7))
    spo2_preg_flag = int(spo2 < 96 and is_pregnant == 1)
    stress_luteal  = 0.0
    cv_strain      = (max(hr - 70, 0) * 0.3 +
                      max(97 - spo2, 0) * 2.0 +
                      max(temp - 37.0, 0) * 5.0)
    hr_rest_flag   = int(hr > 90 and motion < 2)
    menopause_risk = int(menopausal == 1 and hr > 90)

    return [hr, spo2, temp, stress, motion,
            cycle_phase, is_pregnant, menopausal, age,
            hr_phase_dev, temp_phase_dev,
            spo2_preg_flag, stress_luteal, cv_strain,
            hr_rest_flag, menopause_risk]

# ─────────────────────────────────────────────────────────────
#  TRANSPARENT EXPLANATION ENGINE
# ─────────────────────────────────────────────────────────────
def explain(hr, spo2, temp, motion,
            cycle_phase, is_pregnant, menopausal, age, label, probs):

    phase      = phase_names.get(int(cycle_phase), 'Unknown')
    phase_hr   = phase_hr_norms.get(int(cycle_phase), 72)
    phase_temp = phase_temp_norms.get(int(cycle_phase), 36.7)

    analysis = []
    advice   = []
    context  = []

    # ── Heart Rate ──
    hr_dev = hr - phase_hr
    if hr > 110:
        analysis.append(f"⚠ Heart rate critically elevated: {hr:.0f} BPM (expected ~{phase_hr} in {phase} phase)")
        advice.append("Sit down immediately. Breathe slowly. Seek medical help if persistent.")
    elif hr > 95:
        analysis.append(f"↑ Heart rate elevated: {hr:.0f} BPM (+{hr_dev:.0f} above {phase} norm of {phase_hr} BPM)")
        advice.append("Rest for 10 minutes. Avoid caffeine.")
    elif hr < 55:
        analysis.append(f"↓ Heart rate low: {hr:.0f} BPM — check if athletic baseline or medication")
    else:
        analysis.append(f"✓ Heart rate normal for {phase} phase: {hr:.0f} BPM")

    # ── SpO2 ──
    spo2_thresh = 96 if is_pregnant else 95
    if spo2 < 92:
        analysis.append(f"🚨 SpO₂ critically low: {spo2:.0f}% — emergency threshold")
        advice.append("Sit upright NOW. Call emergency services if below 90%.")
    elif spo2 < spo2_thresh:
        analysis.append(f"↓ SpO₂ reduced: {spo2:.0f}% (threshold: {spo2_thresh}%{'  pregnancy mode' if is_pregnant else ''})")
        advice.append("Breathe slowly and deeply. Check sensor placement.")
    else:
        analysis.append(f"✓ SpO₂ normal: {spo2:.0f}%")

    # ── Temperature ──
    temp_dev = temp - phase_temp
    if temp > 38.5:
        analysis.append(f"🚨 Temperature critically high: {temp:.1f}°C — possible fever")
        advice.append("Hydrate immediately. Seek medical attention.")
    elif temp > 37.5:
        if cycle_phase == 2:
            analysis.append(f"ℹ Temperature {temp:.1f}°C — elevated but Luteal phase BBT rise is normal (+0.3–0.5°C expected)")
        else:
            analysis.append(f"↑ Temperature elevated: {temp:.1f}°C (+{temp_dev:.1f}°C above {phase} baseline of {phase_temp:.1f}°C)")
    else:
        analysis.append(f"✓ Temperature normal for {phase} phase: {temp:.1f}°C (baseline {phase_temp:.1f}°C)")

    # ── Motion ──
    if motion > 6:
        context.append(f"🏃 High motion ({motion:.1f} m/s²) — elevated HR may be exercise-related, not cardiac")
    elif motion < 1 and hr > 90:
        context.append(f"⚠ Low motion ({motion:.1f} m/s²) + elevated HR — resting tachycardia flag")

    # ── Pregnancy ──
    if is_pregnant:
        context.append("🤰 PREGNANCY MODE: SpO₂ threshold tightened to 96%, HR baseline +10–15 BPM")
        if hr > 110:
            context.append("   ⚠ HR >110 in pregnancy — monitor for preeclampsia signs")
        if spo2 < 95:
            context.append("   ⚠ SpO₂ <95% in pregnancy — contact OB/GYN promptly")

    # ── Menopause ──
    if menopausal:
        context.append("📊 POST-MENOPAUSAL: Estrogen loss → elevated CVD baseline. HR >90 weighted more heavily.")

    # ── Cycle ──
    context.append(f"🌙 {phase} phase — HR norm ~{phase_hr} BPM, Temp baseline {phase_temp:.1f}°C")

    return {
        'analysis': analysis,
        'advice':   advice,
        'context':  context
    }

# ─────────────────────────────────────────────────────────────
#  PROCESS ONE READING
# ─────────────────────────────────────────────────────────────
def process_reading(hr, spo2, temp, motion,
                    cycle_phase, is_pregnant, menopausal, age):

    features = build_features(hr, spo2, temp, motion,
                               cycle_phase, is_pregnant, menopausal, age)
    arr      = np.array([features])
    label    = int(model.predict(arr)[0])
    probs    = model.predict_proba(arr)[0]
    conf     = float(probs[label]) * 100

    phase    = phase_names.get(int(cycle_phase), 'Unknown')
    status   = label_names[label]
    ts       = datetime.now().strftime('%H:%M:%S')

    expl = explain(hr, spo2, temp, motion,
                   cycle_phase, is_pregnant, menopausal, age,
                   label, probs)

    # Console print
    icons = {0: '✅', 1: '⚠️ ', 2: '🚨'}
    print(f"\n{'='*55}")
    print(f"  [{ts}] New Reading")
    print(f"  HR: {hr:.0f} BPM  SpO₂: {spo2:.0f}%  Temp: {temp:.1f}°C  Motion: {motion:.1f}")
    print(f"  Phase: {phase}  Pregnant: {'Yes' if is_pregnant else 'No'}  Age: {age:.0f}")
    print(f"  {icons[label]} STATUS: {status.upper()}  (Confidence: {conf:.0f}%)")
    print(f"  Probabilities → Normal: {probs[0]*100:.0f}%  Elevated: {probs[1]*100:.0f}%  Critical: {probs[2]*100:.0f}%")
    print(f"\n  Analysis:")
    for a in expl['analysis']:   print(f"    {a}")
    if expl['context']:
        print(f"\n  Women's Health Context:")
        for c in expl['context']: print(f"    {c}")
    if expl['advice']:
        print(f"\n  Advice:")
        for a in expl['advice']:  print(f"    → {a}")
    print(f"{'='*55}")

    # Build result for Flutter app
    result = {
        'timestamp':   ts,
        'vitals': {
            'heart_rate':  hr,
            'spo2':        spo2,
            'temperature': temp,
            'motion':      motion,
            'stress_level': 0.0,   # GSR removed — kept for Flutter model compat
            'oxygen_level': spo2,
            'motion_level': motion,
        },
        'context': {
            'cycle_phase':  int(cycle_phase),
            'phase_name':   phase,
            'is_pregnant':  bool(is_pregnant),
            'menopausal':   bool(menopausal),
            'age':          age,
        },
        'result': {
            'label':        label,
            'status':       status,
            'overall_status': status.lower().replace(' ', '_'),
            'confidence':   round(conf, 1),
            'probabilities': {
                'normal':   round(float(probs[0]) * 100, 1),
                'elevated': round(float(probs[1]) * 100, 1),
                'critical': round(float(probs[2]) * 100, 1),
            }
        },
        'explanation': expl,
        'source': 'esp32'
    }

    with result_lock:
        global latest_result
        latest_result = result

# ─────────────────────────────────────────────────────────────
#  SERIAL READER THREAD
#  Reads ESP32 on COM3 continuously
#  Expected format from ESP32:
#  HR,SPO2,TEMP,MOTION,CYCLE_PHASE,IS_PREGNANT,MENOPAUSAL,AGE
#  Example: 78,97,36.8,3.2,0,0,0,32
# ─────────────────────────────────────────────────────────────
def serial_reader():
    print("[2/3] Connecting to ESP32 on", SERIAL_PORT, "...")
    while True:
        try:
            ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=3)
            print(f"  ✅ ESP32 connected on {SERIAL_PORT}\n")
            while True:
                try:
                    line = ser.readline().decode('utf-8', errors='ignore').strip()
                    if not line:
                        continue

                    # Parse CSV from ESP32
                    # Format: HR,SPO2,TEMP,MOTION,CYCLE_PHASE,IS_PREGNANT,MENOPAUSAL,AGE
                    parts = line.split(',')
                    if len(parts) < 4:
                        continue

                    hr          = float(parts[0])
                    spo2        = float(parts[1])
                    temp        = float(parts[2])
                    motion      = float(parts[3]) if len(parts) > 3 else 3.0
                    cycle_phase = int(parts[4])   if len(parts) > 4 else 0
                    is_pregnant = int(parts[5])   if len(parts) > 5 else 0
                    menopausal  = int(parts[6])   if len(parts) > 6 else 0
                    age         = float(parts[7]) if len(parts) > 7 else 30.0

                    process_reading(hr, spo2, temp, motion,
                                    cycle_phase, is_pregnant, menopausal, age)

                except ValueError:
                    continue  # Skip malformed lines
                except Exception as e:
                    print(f"  Read error: {e}")
                    continue

        except serial.SerialException as e:
            print(f"  ⚠ Serial error: {e}")
            print(f"  Retrying in 5 seconds...")
            time.sleep(5)
            continue

# ─────────────────────────────────────────────────────────────
#  FLASK API — Flutter app connects here
# ─────────────────────────────────────────────────────────────
app = Flask(__name__)
CORS(app)  # Allow Flutter app from any origin

@app.route('/latest', methods=['GET'])
def get_latest():
    """Flutter app polls this every 10 seconds for latest AI result"""
    with result_lock:
        return jsonify(latest_result)

@app.route('/analyze', methods=['POST'])
def analyze_manual():
    """
    Flutter app can POST manual vitals for immediate analysis
    Body: {"hr":78,"spo2":97,"temp":36.8,"motion":3.0,
           "cycle_phase":0,"is_pregnant":0,"menopausal":0,"age":32}
    """
    try:
        d = request.json
        hr          = float(d.get('hr', 75))
        spo2        = float(d.get('spo2', 97))
        temp        = float(d.get('temp', 36.7))
        motion      = float(d.get('motion', 3.0))
        cycle_phase = int(d.get('cycle_phase', 0))
        is_pregnant = int(d.get('is_pregnant', 0))
        menopausal  = int(d.get('menopausal', 0))
        age         = float(d.get('age', 30))

        process_reading(hr, spo2, temp, motion,
                        cycle_phase, is_pregnant, menopausal, age)
        with result_lock:
            return jsonify(latest_result)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/health', methods=['GET'])
def health_check():
    """Flutter app can call this to check if Python server is running"""
    return jsonify({
        'status':    'running',
        'model':     'cvd_model.pkl',
        'cv_score':  pkg['cv_score'],
        'datasets':  pkg['datasets_used'],
        'serial':    SERIAL_PORT,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/ai/chat', methods=['POST'])
def ai_chat():
    """
    AI chat endpoint for Flutter chat screen
    Body: {"message": "...", "conversation_id": "...", "context": {...}}
    """
    try:
        d       = request.json
        msg     = d.get('message', '')
        ctx     = d.get('context', {})

        with result_lock:
            vitals = latest_result.get('vitals', {})
            result = latest_result.get('result', {})
            expl   = latest_result.get('explanation', {})
            phase  = latest_result.get('context', {}).get('phase_name', 'Unknown')

        # Rule-based AI response using current vitals + explanation
        response = generate_chat_response(msg, vitals, result, expl, phase)
        return jsonify({'response': response})
    except Exception as e:
        return jsonify({'response': f'I had trouble processing that. Error: {str(e)}'}), 200

def generate_chat_response(msg, vitals, result, expl, phase):
    """
    Transparent AI chat — uses current vitals + model output to answer
    No external API needed — works fully offline
    """
    msg_lower = msg.lower()

    hr   = vitals.get('heart_rate', 0)
    spo2 = vitals.get('spo2', 0)
    temp = vitals.get('temperature', 0)
    status = result.get('status', 'Unknown')
    conf   = result.get('confidence', 0)

    # Heart rate questions
    if any(w in msg_lower for w in ['heart rate', 'hr', 'bpm', 'pulse', 'heartbeat']):
        analysis = next((a for a in expl.get('analysis', []) if 'Heart rate' in a or 'heart rate' in a), '')
        return (f"Your current heart rate is {hr:.0f} BPM. {analysis}\n\n"
                f"The model assessed this as part of your overall {status} status "
                f"(confidence: {conf:.0f}%). "
                f"Normal resting heart rate for women is 60–100 BPM, though this "
                f"varies by cycle phase — you're currently in the {phase} phase, "
                f"which has its own adjusted baseline. Always consult your doctor if "
                f"HR is consistently above 100 BPM at rest.")

    # Oxygen / SpO2 questions
    if any(w in msg_lower for w in ['oxygen', 'spo2', 'o2', 'saturation', 'breathe', 'breathing']):
        analysis = next((a for a in expl.get('analysis', []) if 'SpO' in a), '')
        return (f"Your current SpO₂ is {spo2:.0f}%. {analysis}\n\n"
                f"Normal SpO₂ is 95–100%. Below 95% warrants attention; below 92% "
                f"is a medical emergency. If you feel short of breath, sit upright "
                f"and take slow deep breaths. Always consult a doctor if this persists.")

    # Temperature questions
    if any(w in msg_lower for w in ['temperature', 'temp', 'fever', 'hot', 'warm']):
        analysis = next((a for a in expl.get('analysis', []) if 'Temperature' in a or 'temperature' in a), '')
        return (f"Your current temperature is {temp:.1f}°C. {analysis}\n\n"
                f"Note: In the {phase} phase, basal body temperature can naturally "
                f"rise by 0.3–0.5°C due to progesterone. This is tracked by our "
                f"menstrual cycle dataset (Menstrual Cycle & Health Data). "
                f"Above 38.5°C warrants medical attention.")

    # Cycle / period questions
    if any(w in msg_lower for w in ['cycle', 'period', 'menstrual', 'phase', 'luteal', 'follicular', 'ovulation']):
        return (f"You're currently in the {phase} phase of your menstrual cycle. "
                f"This affects your vitals:\n"
                f"• Follicular: Lowest HR & temp — best cardiovascular performance window\n"
                f"• Ovulation: Brief HR spike possible (+3–8 BPM)\n"
                f"• Luteal: HR +5–10 BPM, Temp +0.3–0.5°C, higher stress sensitivity\n"
                f"• Menstrual: Slight HR elevation from blood loss\n\n"
                f"Our AI adjusts your alert thresholds based on this phase to avoid "
                f"false alarms. Source: Menstrual Cycle & Health Data + MAMA-Sens datasets.")

    # Status / overall
    if any(w in msg_lower for w in ['status', 'overall', 'risk', 'safe', 'okay', 'ok', 'fine', 'how am i']):
        analysis_list = '\n'.join([f'• {a}' for a in expl.get('analysis', [])])
        context_list  = '\n'.join([f'• {c}' for c in expl.get('context', [])])
        return (f"Your current status is: {status.upper()} (confidence: {conf:.0f}%)\n\n"
                f"Here's what the AI found:\n{analysis_list}\n\n"
                f"Context applied:\n{context_list}\n\n"
                f"Please consult a doctor for any medical decisions.")

    # Advice
    if any(w in msg_lower for w in ['advice', 'what should i do', 'help', 'recommend']):
        advice_list = '\n'.join([f'→ {a}' for a in expl.get('advice', ['Keep monitoring your vitals regularly.'])])
        return f"Based on your current readings, here's my advice:\n\n{advice_list}\n\nRemember: I'm an AI assistant. Always consult a qualified doctor for medical decisions."

    # Datasets
    if any(w in msg_lower for w in ['dataset', 'trained', 'data', 'how do you know', 'source']):
        return ("I was trained on 9 women-focused datasets:\n"
                "• CVD Kaggle — baseline cardiovascular risk factors\n"
                "• PTB-XL & MIT-BIH — ECG arrhythmia patterns (female norms)\n"
                "• WESAD — wearable stress detection\n"
                "• PPG-DaLiA — activity-adjusted heart rate\n"
                "• BIDMC — clinical SpO₂ & HR thresholds\n"
                "• Menstrual Cycle Data — cycle-phase vital baselines\n"
                "• Sleep Health — sleep deprivation cardiac effects\n"
                "• MAMA-Sens — pregnancy trimester baselines\n"
                "• MatSENSE + PreCare — prenatal & preeclampsia patterns\n\n"
                "Every alert references which dataset informed that threshold. "
                "This makes our AI transparent — not a black box.")

    # Default
    return (f"Based on your latest readings (HR: {hr:.0f} BPM, SpO₂: {spo2:.0f}%, "
            f"Temp: {temp:.1f}°C), your overall status is {status}.\n\n"
            f"I'm your cardiac health AI, trained on 9 women-focused datasets. "
            f"I can answer questions about your heart rate, oxygen levels, temperature, "
            f"menstrual cycle effects on vitals, pregnancy, and more.\n\n"
            f"Always consult a doctor for medical decisions.")

# ─────────────────────────────────────────────────────────────
#  MAIN — Start both threads
# ─────────────────────────────────────────────────────────────
if __name__ == '__main__':
    print("[2/3] Starting serial reader thread...")
    serial_thread = threading.Thread(target=serial_reader, daemon=True)
    serial_thread.start()

    print("[3/3] Starting Flask API...")
    print(f"\n{'='*55}")
    print(f"  🚀 System Running!")
    print(f"{'='*55}")
    print(f"  Flask API:     http://localhost:{FLASK_PORT}")
    print(f"  ESP32 Port:    {SERIAL_PORT}")
    print(f"  Flutter polls: GET  http://YOUR_PC_IP:{FLASK_PORT}/latest")
    print(f"  AI Chat:       POST http://YOUR_PC_IP:{FLASK_PORT}/ai/chat")
    print(f"  Health check:  GET  http://YOUR_PC_IP:{FLASK_PORT}/health")
    print(f"\n  ⚠  Flutter app must use your PC's local IP, not localhost")
    print(f"     Find your IP: ipconfig (Windows) → IPv4 Address")
    print(f"{'='*55}\n")

    app.run(host=FLASK_HOST, port=FLASK_PORT, debug=False, use_reloader=False)
