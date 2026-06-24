
from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
from datetime import datetime
import os

print("Current folder:", os.getcwd())
print("Files here:", os.listdir())
app = Flask(__name__)
CORS(app)  # Allow mobile app to call this

# Load model once at startup
print("Loading model...")
pkg = joblib.load('cvd_model.pkl')
model = pkg['model']
feature_cols = pkg['feature_cols']
label_names = pkg['label_names']
phase_names = pkg['phase_names']
phase_hr_norms = pkg['phase_hr_norms']
phase_temp_norms = pkg['phase_temp_norms']
print("✅ Model loaded and API ready\n")

# Latest reading stored in memory
latest_reading = {}

def build_features(hr, spo2, temp, stress, motion,
                   cycle_phase, is_pregnant, menopausal, age):
    hr_phase_dev = abs(hr - phase_hr_norms.get(int(cycle_phase), 72))
    temp_phase_dev = abs(temp - phase_temp_norms.get(int(cycle_phase), 36.7))
    spo2_preg_flag = int(spo2 < 96 and is_pregnant == 1)
    stress_luteal = stress if cycle_phase == 2 else 0.0
    cv_strain = (max(hr - 70, 0) * 0.3 +
                 max(97 - spo2, 0) * 2.0 +
                 max(temp - 37.0, 0) * 5.0 +
                 stress * 0.1)
    hr_rest_flag = int(hr > 90 and motion < 2)
    menopause_risk = int(menopausal == 1 and hr > 90)
    return [hr, spo2, temp, stress, motion,
            cycle_phase, is_pregnant, menopausal, age,
            hr_phase_dev, temp_phase_dev,
            spo2_preg_flag, stress_luteal, cv_strain,
            hr_rest_flag, menopause_risk]

# ─────────────────────────────────────────────────────────────
#  ENDPOINT 1: Receive from serial_reader.py
# ─────────────────────────────────────────────────────────────
@app.route('/analyze', methods=['POST'])
def receive_from_reader():
    global latest_reading
    data = request.json
    latest_reading = data
    latest_reading['received_at'] = datetime.now().isoformat()
    return jsonify({'success': True})

# ─────────────────────────────────────────────────────────────
#  ENDPOINT 2: Mobile app polls for latest result
# ─────────────────────────────────────────────────────────────
@app.route('/latest', methods=['GET'])
def get_latest():
    return jsonify(latest_reading if latest_reading else {'status': 'waiting'})

# ─────────────────────────────────────────────────────────────
#  ENDPOINT 3: Mobile app sends manual vitals for analysis
# ─────────────────────────────────────────────────────────────
@app.route('/predict', methods=['POST'])
def predict():
    """
    POST body:
    {
      "hr": 88, "spo2": 96, "temp": 37.1, "stress": 65,
      "motion": 3.0, "cycle_phase": 2, "is_pregnant": 0,
      "menopausal": 0, "age": 32
    }
    """
    d = request.json
    try:
        features = build_features(
            float(d.get('hr', 75)),
            float(d.get('spo2', 97)),
            float(d.get('temp', 36.8)),
            float(d.get('stress', 40)),
            float(d.get('motion', 3)),
            int(d.get('cycle_phase', 0)),
            int(d.get('is_pregnant', 0)),
            int(d.get('menopausal', 0)),
            float(d.get('age', 30))
        )
        arr = np.array([features])
        label = int(model.predict(arr)[0])
        probs = model.predict_proba(arr)[0]

        return jsonify({
            'label': label,
            'status': label_names[label],
            'confidence': round(float(probs[label]) * 100, 1),
            'probabilities': {
                'normal':   round(float(probs[0]) * 100, 1),
                'elevated': round(float(probs[1]) * 100, 1),
                'critical': round(float(probs[2]) * 100, 1)
            },
            'phase': phase_names.get(int(d.get('cycle_phase', 0)), 'Unknown')
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

# ─────────────────────────────────────────────────────────────
#  ENDPOINT 4: Health check
# ─────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'running',
        'model_cv_score': pkg['cv_score'],
        'datasets': pkg['datasets_used'],
        'bias_note': pkg['bias'],
        'version': pkg['version']
    })

if __name__ == '__main__':
    print("🚀 Flask API running on http://localhost:5000")
    print("   Endpoints:")
    print("   POST /analyze  — receives data from serial_reader.py")
    print("   GET  /latest   — mobile app polls for latest result")
    print("   POST /predict  — manual vitals → AI prediction")
    print("   GET  /health   — model info\n")
    app.run(host='0.0.0.0', port=5000, debug=False)
