"""Local development launcher: load only documented env names, without shell evaluation."""
import os
from pathlib import Path
import uvicorn

def load_environment():
    path=Path(__file__).with_name('.env')
    if path.exists():
        for line in path.read_text().splitlines():
            name,separator,value=line.partition('=')
            if separator and name.strip() in {'GROQ_API_KEY','GROQ_MODEL'}:
                os.environ.setdefault(name.strip(),value.strip().strip('"\''))

if __name__=='__main__':
    load_environment()
    uvicorn.run('avelo_backend.app:app',host='127.0.0.1',port=8001,access_log=False)
