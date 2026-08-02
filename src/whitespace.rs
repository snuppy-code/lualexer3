use crate::{token::Token, util::trim_start_while};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Whitespace;

pub fn lex_whitespace<'i>(view: &'i str) -> Option<(Token<'i>, &'i str)> {
    trim_start_while(view, |b| !b.is_ascii_whitespace())
}
