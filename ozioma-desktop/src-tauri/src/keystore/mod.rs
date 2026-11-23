use keyring::Entry;

pub fn get_congregation_master_key(congregation_id: &str) -> Result<String, keyring::Error> {
    let entry = Entry::new("ozioma_desktop", congregation_id)?;
    entry.get_password()
}

pub fn set_congregation_master_key(congregation_id: &str, key: &str) -> Result<(), keyring::Error> {
    let entry = Entry::new("ozioma_desktop", congregation_id)?;
    entry.set_password(key)
}
