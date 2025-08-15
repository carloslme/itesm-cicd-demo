from sklearn.datasets import load_iris
import pandas as pd
from pathlib import Path

out = Path("src/training/data/iris.csv")
out.parent.mkdir(parents=True, exist_ok=True)

iris = load_iris(as_frame=True)
df = iris.frame
df.rename(columns={
    "sepal length (cm)": "sepal_length",
    "sepal width (cm)": "sepal_width",
    "petal length (cm)": "petal_length",
    "petal width (cm)": "petal_width",
    "target": "species"
}, inplace=True)
df["species"] = df["species"].map(dict(enumerate(iris.target_names)))
df.to_csv(out, index=False)
print(f"Wrote {out} ({len(df)} rows)")