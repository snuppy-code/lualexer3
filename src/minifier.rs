use crate::{parser::parse::parse, semantic::bind::bind};

pub fn minify(input: &str) -> String {
    let tokens = lex(input);
    let ast = parse(tokens);
    let bound_ast = bind(ast);
}
