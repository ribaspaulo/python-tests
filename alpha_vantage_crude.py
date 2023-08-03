import requests
import pandas as pd

MKEY = '02OZUM3E4V2QYXXT'
CRUDE = 'WTI'
# replace the "demo" apikey below with your own key from https://www.alphavantage.co/support/#api-key
url = f'https://www.alphavantage.co/query?function={CRUDE}&interval=daily&apikey={MKEY}'
r = requests.get(url)
data = r.json()

#df = pd.DataFrame(data)


df = pd.json_normalize(data, record_path =['data'])



print(df)