import pypandoc

# Konversi file markdown ke docx
input_file = 'PROPOSAL.md' 
output_file = 'PROPOSAL.docx'  

output = pypandoc.convert_file(input_file, 'docx', outputfile=output_file)
print(f'File berhasil dikonversi ke {output_file}')
