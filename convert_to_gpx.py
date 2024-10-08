import json
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta

def create_gpx(route):
    gpx = ET.Element('gpx', version="1.1", creator="Xcode")
    
    # Lajitellaan pisteet aikaleiman mukaan nousevaan järjestykseen
    sorted_points = sorted(route['points'], key=lambda x: x['timestamp'])
    
    for idx, point in enumerate(sorted_points, start=1):
        wpt = ET.SubElement(gpx, 'wpt', lat=str(point['latitude']), lon=str(point['longitude']))
        ele = ET.SubElement(wpt, 'ele')
        ele.text = str(point['altitude'])
        time = ET.SubElement(wpt, 'time')
        timestamp = datetime(2001, 1, 1) + timedelta(seconds=point['timestamp'])
        time.text = timestamp.strftime('%Y-%m-%dT%H:%M:%SZ')
        name = ET.SubElement(wpt, 'name')
        name.text = f"Point {idx}"
        desc = ET.SubElement(wpt, 'desc')
        desc.text = f"Speed: {point['speed']} m/s, Heading: {point['heading']} degrees"
    
    return ET.tostring(gpx, encoding='unicode', xml_declaration=True)

def main():
    with open('route.json', 'r') as f:
        route = json.load(f)

    gpx_data = create_gpx(route)

    with open('route.gpx', 'w') as f:
        f.write(gpx_data)

if __name__ == "__main__":
    main()
