#!/usr/bin/env python3
from starkware.crypto.signature.signature import private_to_stark_key, get_random_private_key, sign
from starknet_py.hash.utils import pedersen_hash

priv_key = 123
# priv_key = get_random_private_key()
# print("priv_key:", hex(priv_key))
pub_key = private_to_stark_key(priv_key)
print("pub_key:", hex(pub_key))

user_addr = 0x123
encoded_string = 2511989689804727759073888271181282305524144280507626647406
message_hash = pedersen_hash(user_addr, encoded_string)

(x, y) = sign(message_hash, priv_key)
print("sig:", hex(x), hex(y))