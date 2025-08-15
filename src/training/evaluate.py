def evaluate_model(model, X_test, y_test):
    from sklearn.metrics import accuracy_score, classification_report

    # Make predictions
    y_pred = model.predict(X_test)

    # Calculate accuracy
    accuracy = accuracy_score(y_test, y_pred)

    # Generate classification report
    report = classification_report(y_test, y_pred)

    return accuracy, report


if __name__ == "__main__":
    import pandas as pd
    import pickle
    from sklearn.model_selection import train_test_split

    # Load the dataset
    data = pd.read_csv('src/training/data/iris.csv')
    X = data.drop('species', axis=1)
    y = data['species']

    # Split the dataset into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Load the trained model
    with open('src/api/models/iris_v2.pkl', 'rb') as model_file:
        model = pickle.load(model_file)

    # Evaluate the model
    accuracy, report = evaluate_model(model, X_test, y_test)

    print(f"Model Accuracy: {accuracy}")
    print("Classification Report:")
    print(report)