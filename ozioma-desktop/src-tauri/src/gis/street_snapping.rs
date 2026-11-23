use geo::{Coord, Point};

pub fn snap_point_to_nearest_street(
    target: Point<f64>,
    street_vertices: &[Coord<f64>],
    threshold_meters: f64,
) -> Option<Point<f64>> {
    let mut closest_point = None;
    let mut min_distance = f64::MAX;

    for vertex in street_vertices {
        let pt = Point::new(vertex.x, vertex.y);
        // Approximate planar distance in degrees (~111km/deg)
        let dx = (target.x() - pt.x()) * 111320.0;
        let dy = (target.y() - pt.y()) * 111320.0;
        let dist = (dx * dx + dy * dy).sqrt();

        if dist < threshold_meters && dist < min_distance {
            min_distance = dist;
            closest_point = Some(pt);
        }
    }

    closest_point
}
