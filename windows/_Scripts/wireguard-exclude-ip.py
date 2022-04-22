from ipaddress import ip_network

start = '0.0.0.0/0'
exclude = ['192.168.0.0/16', '10.0.0.0/8']

result = [ip_network(start)]
for x in exclude:
    n = ip_network(x)
    new = []
    for y in result:
        if y.overlaps(n):
            new.extend(y.address_exclude(n))
        else:
            new.append(y)
    result = new

print(','.join(str(x) for x in sorted(result)))