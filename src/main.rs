use luaminifier2::minifier::minify;

fn main() {
    todo!();
    // real code here will be something like:
    // get inputs
    // use minifier with options
    let input = "for i = 1,3 do john = \"bingus\"\npork= 3+2*(1/2<<0x2) end";
    let output = minify(&input);
    dbg!(output)
    // manage output
}

// https://web.stanford.edu/class/archive/cs/cs143/cs143.1128/handouts/020%20CS143%20Course%20Overview.pdf
