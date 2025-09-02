import pandas as pd

def chk_types(df):
    dtypes = df.dtypes
    n_unique = df.nunique()
    return pd.DataFrame({"Dtypes": dtypes, "Num_uniques": n_unique}).T