{
    "name": "Vykia Base",
    "summary": "Common base of Vykia Odoo instances: full-screen app menu",
    "version": "19.0.1.0.0",
    "category": "Hidden",
    "author": "Vykia",
    "license": "LGPL-3",
    "depends": [
        "web",
        # OCA: full-screen home menu with the app grid and menu search.
        "web_responsive",
    ],
    # Installed automatically in every new database (as soon as "web" is),
    # which brings web_responsive with it.
    "auto_install": ["web"],
    "installable": True,
}
