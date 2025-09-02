
import pandas as pd

path = r"c:/Users/Khaled/Downloads/Data_Preprocessing.csv"

def read_file(path):
    df = pd.read_csv(path)
    return df.head()

print(read_file(path))