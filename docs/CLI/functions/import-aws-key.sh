#
# import aws-key 
#

KEY_NAME=aws-key
echo -e '=cYA2KoJhl3/OnF8mIFEKS97ANbnXp2B+5gfpmhy9VE+xgLC3OirUsa1rG0wkDpPkywJiNBfylYl/CnF0UiVOOTL26NzAVT7ESKRvnYUT8+KI8EfKS5+8kJ4lpLcIA64S/HGAAGM3YMPcltivGAwXeqIQTEEBtDXoxrOejh10fiQNnsBShMJZaQFFBi7AfLgk1JRuELhteO7G/zgnw/Sx7eVHiPJjdfZmC2aBH0yyQPtfJ+15B5gu3TvrSkclCNQfT3oLE1jml72jSxhQGP7VKm99bpqelDoZcWEMq+iYjZWRHMUfILx7X1dftPkcNaDAahI58TyyX9tr0Etwclvn1WXs4UCfe5UewWZWr23noWAJGB0g4K1tfohOZ3DKwMl8IwsBPvd3YgTcqE6ulZLGyLkMTpJ/Pzn1ldc0rgwKC1aRXIzspJnGi3GgL+w0R5sjdZpdhrWqg7hFbMQ1Hv0QaxzgaQc/GXRqjCQCbUleGITxhz5Fge0xKhIFLI0MWY7GDQgBAAABAQADAAAAE2cy1CazN3BAAAA asr-hss\c' |rev |base64 -w 0 >/tmp/my-key-pair.pub
aws ec2 import-key-pair --key-name ${KEY_NAME} --public-key-material file:///tmp/my-key-pair.pub

