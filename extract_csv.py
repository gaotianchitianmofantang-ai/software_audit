import sys
import csv
import json
import os

csv_path = os.environ.get('CSV_PATH', '')

try:
    with open(csv_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    from io import StringIO
    csv_reader = csv.reader(StringIO(content))
    rows = list(csv_reader)
    
    if len(rows) == 0:
        print(json.dumps({"error": "CSVが空です"}), file=sys.stderr)
        sys.exit(1)
    
    data = rows[0]
    
    def get_value(index, default=""):
        return data[index].strip() if index < len(data) else default
    
    info = {
        "申請番号": get_value(0),
        "申請者": get_value(1),
        "申請日時": get_value(3),
        "所属": get_value(7),
        "ソフトウェア名": get_value(9),
        "主な機能": get_value(10),
        "参考URL": get_value(11),
        "有償無償": get_value(12),
        "利用目的": get_value(17)
    }
    
    print(json.dumps(info, ensure_ascii=False, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}), file=sys.stderr)
    sys.exit(1)
