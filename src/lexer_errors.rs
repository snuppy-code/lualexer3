use std::fmt::{self, Display};

use crate::token::Span;

#[derive(Debug, PartialEq)]
pub struct LexerError<'i> {
    kind: LexerErrorKind,
    span: Span<'i>,
}

impl<'i> Display for LexerError<'i> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Lexer error at {}: {}", self.span, self.kind)
    }
}

#[derive(Debug, PartialEq)]
pub enum LexerErrorKind {
    UnclosedLongComment,                         // from to rest of file
    InvalidStringuEscapeMissingOpenBrace,        // from until after 4 spaces
    InvalidStringuEscapeMissingClosingBrace,     // from start of until after 2 spaces
    InvalidStringuEscapeInvalidChar(u8),         // this token
    InvalidStringuEscapeNoDigits,                // this token
    InvalidStringuEscapeBeyond0x10FFFF,          // this token
    InvalidStringxEscapeUnfinished,              // from start until after 2 spaces
    InvalidStringxEscapeInvalidPossiblyTooLarge, // this token
    InvalidStringDecimalEscapeBeyondu8,          // this token
    InvalidStringEscape,                         // from start until after 1 space
    UnclosedShortString,                         // this line
    UnclosedLongString,                          // from to rest of file
    DecimalNumericConstantNeedsIntOrFracPart,    // from start until after 3 spaces
    HexNumericConstantNeedsIntOrFracPart,        // from start until after 3 spaces
    HexNumericConstantMalformedExponent,         // from start until after 2 spaces
    DecimalNumericConstantMalformedExponent,     // from start until after 2 spaces
}

impl Display for LexerErrorKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            // Self::FailedLexingAll(s) => write!(f,"Encountered unexpected input! remains: `{}`",s),
            Self::UnclosedLongComment => write!(f, "Unclosed long comment"),

            Self::InvalidStringuEscapeMissingOpenBrace => {
                write!(f, "Invalid \\u string escape: Missing opening brace")
            }
            Self::InvalidStringuEscapeMissingClosingBrace => {
                write!(f, "Invalid \\u string escape: Missing closing brace")
            }
            Self::InvalidStringuEscapeInvalidChar(b) => write!(
                f,
                "Invalid \\u string escape: Invalid character (byte value: {b}) in escape sequence"
            ),
            Self::InvalidStringuEscapeNoDigits => write!(
                f,
                "Invalid \\u string escape: No digits in escape sequence (needed to specify codepoint)"
            ),
            Self::InvalidStringuEscapeBeyond0x10FFFF => write!(
                f,
                "Invalid \\u string escape: Beyond Lua 5.3 0x10FFFF limit"
            ),

            Self::InvalidStringxEscapeUnfinished => {
                write!(f, "Unfinished \\x escape sequence at end of string")
            }
            Self::InvalidStringxEscapeInvalidPossiblyTooLarge => {
                write!(f, "Invalid hex, maybe too large? in \\x escape sequence")
            }

            Self::DecimalNumericConstantNeedsIntOrFracPart => write!(
                f,
                "Decimal numeric constant needs at least an integer or fractional part"
            ),
            Self::HexNumericConstantNeedsIntOrFracPart => write!(
                f,
                "Hex numeric constant needs integer part or fractional part!"
            ),
            Self::HexNumericConstantMalformedExponent => {
                write!(f, "Hex numeric constant has malformed exponent")
            }
            Self::DecimalNumericConstantMalformedExponent => {
                write!(f, "Decimal numeric constant has malformed exponent")
            }

            Self::InvalidStringDecimalEscapeBeyondu8 => {
                write!(f, "Invalid decimal string escape: Beyond 255")
            }
            Self::InvalidStringEscape => write!(f, "Unrecognized string escape"),
            Self::UnclosedShortString => write!(f, "Unclosed short string"),
            Self::UnclosedLongString => write!(f, "Unclosed long string"),
        }
    }
}
