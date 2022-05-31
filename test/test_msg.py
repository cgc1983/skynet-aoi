#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys
import json
import msgpack
import msgdef_pb2

data={
        "a":10000000,
        "b":"10000000",
        "c":{
            "a":100000000,
            "b":"100000000",
            }
        }


d1=json.dumps(data)
print(d1)
print("d1=",len(d1))

d2=msgpack.packb(data)
print(d2)
print("d2=",len(d2))


p=msgdef_pb2.Person()
p.a=10000000
p.b="10000000"

x=msgdef_pb2.PhoneNumber()
x.a=10000000
x.b="10000000"


p.c.CopyFrom(x)

d3=p.SerializeToString()
print(d3)
print("d3=",len(d3))


