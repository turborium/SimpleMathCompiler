import math
import datetime

X=10
Y=50
ans=0
a = datetime.datetime.now()
for i in range(0,1000000):
  ans=ans*0.1+math.sin(X) + (math.cos(Y) * math.exp(6) + 23 - 8) * 10
  # ans=ans*0.1+math.sin(X) + (math.cos(Y) * math.exp(6) + 23 - 8) * 10 + X * 0.2 + 0.1 * (X * 0.545 + X * 0.245 + X * 0.765 + Y + 23 + 219 + 93.0)
  X=X+0.1
b = datetime.datetime.now()

print(ans)
print((b-a).microseconds / 1000)