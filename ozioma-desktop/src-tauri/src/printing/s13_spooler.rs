use printpdf::*;
use std::fs::File;
use std::io::BufWriter;
use std::path::Path;

pub fn render_s13_card_pdf(
    territory_number: &str,
    territory_name: &str,
    congregation_name: &str,
    output_path: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    // Standard A4: 210mm x 297mm (4-up cards per A4 page)
    let (doc, page1, layer1) = PdfDocument::new(
        format!("Territory Card {}", territory_number),
        Mm(210.0),
        Mm(297.0),
        "Layer 1",
    );

    let current_layer = doc.get_page(page1).get_layer(layer1);
    let font = doc.add_builtin_font(BuiltinFont::HelveticaBold)?;
    let font_regular = doc.add_builtin_font(BuiltinFont::Helvetica)?;

    // Title & Theocratic Headers
    current_layer.use_text(
        format!("TERRITORY ASSIGNMENT CARD — {}", territory_number),
        16.0,
        Mm(20.0),
        Mm(280.0),
        &font,
    );

    current_layer.use_text(
        format!("Congregation: {} | Territory: {}", congregation_name, territory_name),
        11.0,
        Mm(20.0),
        Mm(272.0),
        &font_regular,
    );

    // Save Vector PDF file
    let path = Path::new(output_path);
    let file = File::create(path)?;
    doc.save(&mut BufWriter::new(file))?;

    Ok(output_path.to_string())
}
