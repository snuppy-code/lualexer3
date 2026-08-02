use crate::change::Change;

pub(crate) fn s(bs: &[u8]) -> &str {
    return str::from_utf8(bs).unwrap();
}
pub(crate) fn trim_start_while(view: &str, predicate: fn(&u8) -> bool) -> Change<&str> {
    let bytes = view.as_bytes();
    let mut cursor = 0;

    while let Some(b) = bytes.get(cursor) {
        if predicate(b) {
            break;
        }
        cursor += 1;
    }
    return Change::from(&view[cursor..], cursor == 0);
}
pub fn trim_start_until_whitespace(view: &str) -> Change<&str> {
    trim_start_while(view, u8::is_ascii_whitespace)
}
