import docx
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def read_docx(path):
    doc = docx.Document(path)
    print(f'--- {path} ---')
    for para in doc.paragraphs:
        if para.text.strip():
            print(para.text)

read_docx('honours_system_specifications_AXI4_Lite.docx')
read_docx('honours_architecture_AXI4_Lite.docx')
