import xml.etree.ElementTree as ET
import os
from datetime import datetime, timedelta
import random

def parse_kml(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    namespace = {'kml': 'http://www.opengis.net/kml/2.2'}
    
    coordinates_elements = root.findall('.//kml:coordinates', namespace)
    points = []
    for coords_elem in coordinates_elements:
        coords_text = coords_elem.text.strip()
        coords_list = coords_text.split()
        for coord in coords_list:
            try:
                lon, lat, *alt = map(float, coord.split(','))
                altitude = alt[0] if alt else 0.0
                point = {
                    'longitude': lon,
                    'latitude': lat,
                    'altitude': altitude,
                    'timestamp': None  # Placeholder for timestamps
                }
                points.append(point)
            except ValueError:
                continue  # Skip any malformed coordinate entries
    
    return points

def generate_random_time_intervals(points):
    start_time = datetime.utcnow()
    for i in range(1, len(points)):
        prev_time = points[i-1]['timestamp']
        if prev_time:
            prev_time = datetime.strptime(prev_time, '%Y-%m-%dT%H:%M:%SZ')
        else:
            prev_time = start_time
        
        random_speed = random.uniform(1, 4)  # Random speed between 1 and 4 m/s
        distance = haversine_distance(points[i-1]['latitude'], points[i-1]['longitude'],
                                      points[i]['latitude'], points[i]['longitude'])
        time_interval = timedelta(seconds=(distance / random_speed))
        points[i]['timestamp'] = (prev_time + time_interval).strftime('%Y-%m-%dT%H:%M:%SZ')
        
        start_time = prev_time + time_interval  # Update start_time for the next iteration
    return points

def haversine_distance(lat1, lon1, lat2, lon2):
    from math import radians, sin, cos, sqrt, atan2
    R = 6371  # Radius of the earth in kilometers
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    distance = R * c * 1000  # Convert to meters
    return distance

def create_gpx(points):
    gpx = ET.Element('gpx', version="1.1", creator="Xcode")
    
    for point in points:
        wpt = ET.SubElement(gpx, 'wpt', lat=str(point['latitude']), lon=str(point['longitude']))
        ele = ET.SubElement(wpt, 'ele')
        ele.text = str(point['altitude'])
        time = ET.SubElement(wpt, 'time')
        time.text = point['timestamp']
    
    return ET.tostring(gpx, encoding='unicode', xml_declaration=True)

def main(kml_path, output_dir):
    points = parse_kml(kml_path)
    points = generate_random_time_intervals(points)
    gpx_data = create_gpx(points)
    
    gpx_output_path = os.path.join(output_dir, 'route.gpx')
    with open(gpx_output_path, 'w') as f:
        f.write(gpx_data)
    
    print(f"Reittipisteitä löydetty: {len(points)}")

if __name__ == "__main__":
    kml_path = 'doc.kml'  # Update the path according to your working directory
    output_dir = './'  # Update the path according to your working directory
    main(kml_path, output_dir)
