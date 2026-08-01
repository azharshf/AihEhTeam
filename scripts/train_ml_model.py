import json
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score

def generate_synthetic_data(n_samples=1000):
    """
    Generates synthetic data matching metabolic syndrome/NHANES characteristics
    to demonstrate training a Random Forest for Dyslipidemia risk prediction.
    """
    np.random.seed(42)
    
    # Generate Features
    age = np.random.randint(18, 80, n_samples)
    bmi = np.random.normal(25, 5, n_samples)
    smoking = np.random.choice([0, 1], n_samples, p=[0.8, 0.2])
    diabetes = np.random.choice([0, 1], n_samples, p=[0.9, 0.1])
    diet_fried = np.random.choice([0, 1, 2], n_samples, p=[0.5, 0.3, 0.2])
    diet_sugar = np.random.choice([0, 1, 2], n_samples, p=[0.4, 0.4, 0.2])
    exercise = np.random.choice([0, 1, 2, 3], n_samples, p=[0.3, 0.4, 0.2, 0.1])
    hypertension = np.random.choice([0, 1], n_samples, p=[0.75, 0.25])
    alcohol = np.random.choice([0, 1, 2], n_samples, p=[0.6, 0.3, 0.1])
    stress = np.random.choice([0, 1, 2], n_samples, p=[0.4, 0.4, 0.2])
    family_history = np.random.choice([0, 1], n_samples, p=[0.85, 0.15])
    
    # Generate Target (Dyslipidemia Risk: 1 = High Risk, 0 = Low Risk)
    # The probability of having dyslipidemia increases with certain factors
    risk_score = (
        (age > 45).astype(float) * 0.15 +
        (bmi > 25).astype(float) * 0.20 +
        smoking * 0.12 +
        diabetes * 0.10 +
        (diet_fried / 2) * 0.08 +
        (diet_sugar / 2) * 0.07 +
        ((3 - exercise) / 3) * 0.08 +
        hypertension * 0.08 +
        (alcohol / 2) * 0.06 +
        (stress / 2) * 0.03 +
        family_history * 0.03
    )
    
    # Introduce some noise
    risk_score += np.random.normal(0, 0.05, n_samples)
    
    # Binary Label (Top 40% are considered at risk)
    threshold = np.percentile(risk_score, 60)
    dyslipidemia = (risk_score >= threshold).astype(int)
    
    df = pd.DataFrame({
        'age': age,
        'bmi': bmi,
        'smoking': smoking,
        'diabetes': diabetes,
        'diet_fried': diet_fried,
        'diet_sugar': diet_sugar,
        'exercise': exercise,
        'hypertension': hypertension,
        'alcohol': alcohol,
        'stress': stress,
        'family_history': family_history,
        'dyslipidemia': dyslipidemia
    })
    
    return df

def train_and_evaluate():
    print("Generating synthetic Metabolic Syndrome dataset...")
    df = generate_synthetic_data(2000)
    
    X = df.drop('dyslipidemia', axis=1)
    y = df['dyslipidemia']
    
    print("Splitting dataset into train/test sets...")
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training Random Forest Classifier...")
    rf_model = RandomForestClassifier(n_estimators=100, max_depth=5, random_state=42)
    rf_model.fit(X_train, y_train)
    
    print("Evaluating Model...")
    y_pred = rf_model.predict(X_test)
    y_prob = rf_model.predict_proba(X_test)[:, 1]
    
    metrics = {
        "Accuracy": float(accuracy_score(y_test, y_pred)),
        "Precision": float(precision_score(y_test, y_pred)),
        "Recall": float(recall_score(y_test, y_pred)),
        "F1-Score": float(f1_score(y_test, y_pred)),
        "ROC-AUC": float(roc_auc_score(y_test, y_prob))
    }
    
    for metric, value in metrics.items():
        print(f"{metric}: {value:.4f}")
        
    print("\nExtracting Feature Importances...")
    feature_importances = list(zip(X.columns, rf_model.feature_importances_))
    feature_importances.sort(key=lambda x: x[1], reverse=True)
    
    weights_dict = {}
    for feature, importance in feature_importances:
        print(f"{feature}: {importance:.4f}")
        weights_dict[feature] = float(importance)
        
    print("\nExporting model parameters to JSON for Web UI...")
    with open('model_weights.json', 'w') as f:
        json.dump(weights_dict, f, indent=4)
        
    print("Done! model_weights.json created.")

if __name__ == "__main__":
    train_and_evaluate()
