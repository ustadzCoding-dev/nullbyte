import hashlib

flags = {
    'm1_l1': 'nullbyte{m1_l1_host_discovery}',
    'm1_l2': 'nullbyte{m1_l2_port_scan}',
    'm1_l3': 'nullbyte{m1_l3_service_fingerprint}',
    'm1_l4': 'nullbyte{m1_l4_file_discovery}',
    'm1_l5': 'nullbyte{m1_l5_flag_extraction}',
    'm2_l1': 'nullbyte{m2_l1_endpoint_discovery}',
    'm2_l2': 'nullbyte{m2_l2_sql_injection}',
    'm2_l3': 'nullbyte{m2_l3_auth_bypass}',
    'm2_l4': 'nullbyte{m2_l4_file_upload_abuse}',
    'm2_l5': 'nullbyte{m2_l5_webshell_pivot}',
    'm3_l1': 'nullbyte{m3_l1_foothold_access}',
    'm3_l2': 'nullbyte{m3_l2_enumeration_sweep}',
    'm3_l3': 'nullbyte{m3_l3_sudo_misconfig}',
    'm3_l4': 'nullbyte{m3_l4_service_pivot}',
    'm3_l5': 'nullbyte{m3_l5_root_access}',
}

json_hashes = {
    'm1_l1': 'f18151d93d0825dacb00dab3487f56336fe0872c86ae430806ce784d52faba94',
    'm1_l2': '72534f2cea7256a3831be36f0e68a1511d0e986f643f993f71a5f2c2d658b4d1',
    'm1_l3': 'd81bb52c11f8df6a06479f1172ffdbcaadf0d2f0082504edbc3cada827d53ec3',
    'm1_l4': '7204d3245caa55e25d3c2b9a2b299a1c75b7be051f96ede31629104059590752',
    'm1_l5': '85aae7dfda766063a669977c20fc006c4110312eb849c1911a9c88bf61724034',
    'm2_l1': 'c5b9e7c3ee89af26fb10a8128ebfa90a7783d3a5329872b14e7cbf13558aa97b',
    'm2_l2': '67f8fe7e47cdfe32a71fe0f5e6d13dda53168ad9c4435ef20311eeb5cbdcf1f3',
    'm2_l3': '2990097ee1ef31b8f4651118ac693a4c016521b9cd835c84a74ce3b69063607b',
    'm2_l4': 'e7cb9e893c8250809a1cffe53a8e3b0b23d56cdfd82b62dbde1ae85f83b113b8',
    'm2_l5': '640c80667dd2767f319f7304ff65791593d4def0a4fdb265b22b182b36f3ee16',
    'm3_l1': 'bafe593bf51f154b27210d5c28ccfc27f4d29bac210726b96fe6fc567ce5f60e',
    'm3_l2': '2e4a4e316451b44804c04643e0c45f329072f2b0b4041073c9b99c2316a14ec7',
    'm3_l3': '94bd8a58e00b03fa32f9ecec922047375bc013c5e87f3d9df0c928b60fd454fd',
    'm3_l4': 'ede295095565d8b748f8f548b2c6ef41eb7cd55305bf6555eb8d175cb408c64a',
    'm3_l5': 'eb31beb8edc5441dd3a33ba7273b29de87937eeeeda2027bef2f20034eedbe9e',
}

all_match = True
for k, f in flags.items():
    computed = hashlib.sha256(f.encode()).hexdigest()
    match = computed == json_hashes[k]
    if not match:
        all_match = False
    print(f'{k}: {f} => {"MATCH" if match else "MISMATCH"}')

print(f'\nAll match: {all_match}')
