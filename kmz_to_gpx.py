import zipfile
import xml.etree.ElementTree as ET
import os

def parse_kml(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    namespace = {'kml': 'http://www.opengis.net/kml/2.2'}
    
    placemarks = root.findall('.//kml:Placemark', namespace)
    points = []
    for placemark in placemarks:
        name_elem = placemark.find('kml:name', namespace)
        coords_elem = placemark.find('.//kml:coordinates', namespace)
        timestamp_elem = placemark.find('.//kml:when', namespace)

        if name_elem is not None and coords_elem is not None:
            name = name_elem.text
            coords = coords_elem.text.strip().replace('\n', '').replace(' ', '').split(',')
            try:
                longitude = float(coords[0])
                latitude = float(coords[1])
                altitude = float(coords[2]) if len(coords) > 2 else 0
            except ValueError:
                continue

            timestamp = timestamp_elem.text if timestamp_elem is not None else None

            point = {
                'name': name,
                'longitude': longitude,
                'latitude': latitude,
                'altitude': altitude,
                'timestamp': timestamp
            }
            points.append(point)
    
    return points

def create_gpx(points):
    gpx = ET.Element('gpx', version="1.1", creator="Xcode")
    
    for idx, point in enumerate(points, start=1):
        wpt = ET.SubElement(gpx, 'wpt', lat=str(point['latitude']), lon=str(point['longitude']))
        ele = ET.SubElement(wpt, 'ele')
        ele.text = str(point['altitude'])
        if point['timestamp']:
            time = ET.SubElement(wpt, 'time')
            time.text = point['timestamp']
        name = ET.SubElement(wpt, 'name')
        name.text = point['name']
    
    return ET.tostring(gpx, encoding='unicode', xml_declaration=True)

def main(kmz_path, output_dir):
    with zipfile.ZipFile(kmz_path, 'r') as kmz:
        kmz.extractall(output_dir)
        kml_file = [f for f in os.listdir(output_dir) if f.endswith('.kml')][0]
        kml_path = os.path.join(output_dir, kml_file)
    
    points = parse_kml(kml_path)
    gpx_data = create_gpx(points)
    
    gpx_output_path = os.path.join(output_dir, 'route.gpx')
    with open(gpx_output_path, 'w') as f:
        f.write(gpx_data)

if __name__ == "__main__":
    kmz_path = 'cp.kmz'
    output_dir = './'
    main(kmz_path, output_dir)
