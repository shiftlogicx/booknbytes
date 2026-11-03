import plistlib

path = '/Users/amitjaydeepsinghthakur/Library/Developer/CoreSimulator/Devices/C62B4222-334C-4BA0-8BCE-CDFA222CFFF2/data/Library/BulletinBoard/VersionedSectionInfo.plist'
with open(path, 'rb') as f:
    d = plistlib.load(f)

sms_bytes = d['sectionInfo']['com.apple.MobileSMS']
inner = plistlib.loads(sms_bytes)

inner['$objects'] = [
    'com.amitthakur.booknbite.hotelApp' if x == 'com.apple.MobileSMS' else ('BookNBytes Restaurant' if x == 'Messages' else x)
    for x in inner['$objects']
]
new_bytes = plistlib.dumps(inner, fmt=plistlib.FMT_BINARY)
d['sectionInfo']['com.amitthakur.booknbite.hotelApp'] = new_bytes

with open(path, 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_BINARY)

print('Successfully injected authorization into VersionedSectionInfo.plist!')
