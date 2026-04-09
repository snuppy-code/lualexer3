use crate::{keyword::{Keyword, lex_ident_or_kw}, literalstring::{LiteralString, lex_long_literal_string, lex_short_literal_string}, numeric_constant::{NumericConstant, lex_numeric_constant}, symbol::{Symbol, lex_symbol}, token::{Span, Token}, token_kind::TokenKind};

#[derive(Debug)]
pub struct Lexer<'i> {
    input: &'i str,
    view: &'i str, // substring of input used in parsing
    tokens: Vec<Token<'i>>,
}

impl<'i> Lexer<'i> {
    pub fn new(input: &'i str) -> Lexer<'i> {
        Lexer {
            input: input,
            view: input,
            tokens: Vec::new(),
        }
    }

    pub fn get_view(&self) -> &'i str {
        &self.view
    }
    pub fn iter_tokens(&self) -> core::slice::Iter<'_,Token<'i>> {
        self.tokens.iter()
    }
    pub fn iter_mut_tokens(&mut self) -> std::slice::IterMut<'_, Token<'i>> {
        self.tokens.iter_mut()
    }
    pub fn view_len(&self) -> usize {
        self.view.len()
    }
    pub fn tokens_len(&self) -> usize {
        self.tokens.len()
    }
    pub fn lex_to_end(&mut self) { 
        'out: loop {
            while self.skip_whitespace() || self.skip_comment() {};

            let token = lex_ident_or_kw(self.view)
                .or_else(|| lex_numeric_constant(self.view))
                .or_else(|| lex_short_literal_string(self.view))
                .or_else(|| lex_long_literal_string(self.view))
                .or_else(|| lex_symbol(self.view))
                ;

            if let Some((token,new_view)) = token {
                self.tokens.push(token);
                self.view = new_view;
            } else {
                break 'out;
            }
        }
        if self.view.len() > 0 {
            panic!("failed lexing all, remains:\n-----\n{}\n----",self.view);
        }
    }
    fn skip_whitespace(&mut self) -> bool {
        let l1 = self.view.len();
        self.view = self.view.trim_start();
        return l1 != self.view.len()
    }
    fn skip_comment(&mut self) -> bool {
        let bytes = self.view.as_bytes();
        
        if !bytes.starts_with(b"--") {
            return false;
        }

        let mut cursor = 2;
        let mut is_long = false;
        let mut opening_eq = 0;

        if bytes.get(cursor) == Some(&b'[') {
            cursor+=1;
            while bytes.get(cursor) == Some(&b'=') {
                cursor+=1;
                opening_eq+=1;
            }
            if bytes.get(cursor) == Some(&b'[') {
                cursor+=1;
                is_long = true;
            }
        }

        // skip short comment
        if !is_long {
            if let Some(newline_pos) = (&bytes[cursor..]).iter().position(|&b| b==b'\n') {
                self.view = &self.view[cursor+newline_pos+1 ..];
            } else {
                self.view = &self.view[self.view.len()..]; // we done,,, end of file
            }
            return true;
        }
        
        // skip long comment
        let mut current = cursor;
        while let Some(bracket_pos) = bytes[current..].iter().position(|&b| b==b']') {
            current+=bracket_pos+1;
            
            let mut closing_eq = 0;
            while bytes.get(current) == Some(&b'=') {
                closing_eq += 1;
                current += 1;
            }

            if closing_eq == opening_eq && bytes.get(current) == Some(&b']') {
                self.view = &self.view[current+1..];
                return true;
            }
        }

        panic!("Unclosed long comment !");
    }
}
