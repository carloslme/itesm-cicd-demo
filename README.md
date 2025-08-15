# 🚀 ML CI/CD Demo

Simple Docker demo: v1 (33% accuracy) → v2 (90% accuracy)

## 🎯 Quick Demo

### Test v1 (Poor Model)
```bash
make v1
# Wait for "Uvicorn running on http://0.0.0.0:8000"
```

**Test:**
```bash
curl http://localhost:8000/model-info
curl "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

### Test v2 (Good Model)
```bash
make v2
# Wait for "Uvicorn running on http://0.0.0.0:8000"
```

**Test:**
```bash
curl http://localhost:8000/model-info
curl "http://localhost:8000/predict?sepal_length=5.1&sepal_width=3.5&petal_length=1.4&petal_width=0.2"
```

## 📊 Expected Results

**v1:** DummyClassifier, 33% accuracy, random predictions
**v2:** RandomForestClassifier, 90% accuracy, smart predictions

## 🛠️ Commands

```bash
make v1     # Poor model (33%)
make v2     # Good model (90%)
make clean  # Clean up
```

**That's it! Simple Docker-only ML CI/CD demo.**