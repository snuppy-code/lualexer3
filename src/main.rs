use crate::lexer_types::{Lexer, Span, TokenKind};

mod lexer_tests;
mod lexer_types;
mod util;

fn main() {
   let s = "[=[abc]=]";
   let mut l = Lexer::new(s);
   l.lex_to_end();
   println!("{:?}",l.iter_tokens().next());
}


/*

*/