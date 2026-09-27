#!/usr/bin/env bash
# Create a new Odoo database, in Spanish, with vykia_base (full-screen menu).
#
#   ./tools/new_db.sh mi_cliente              # empty Odoo in Spanish
#   ./tools/new_db.sh mi_cliente --spain      # + Spanish company and chart of accounts
#   ./tools/new_db.sh mi_cliente --spain -i sale_management,crm
#
# The admin user is "admin" / "admin": change it after the first login.
set -euo pipefail

usage() {
    sed -n '2,8p' "$0"
    exit 1
}

DB="${1:-}"
[[ -z "$DB" || "$DB" == -* ]] && usage
shift
SPAIN=0
MODULES=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --spain) SPAIN=1 ;;
        -i) MODULES="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

cd "$(dirname "$0")/.."
[[ -f config/odoo.conf ]] || { echo "Falta config/odoo.conf: cp config/odoo.conf.example config/odoo.conf"; exit 1; }

docker compose up -d db
if docker compose exec -T db psql -U odoo -lqt | cut -d'|' -f1 | grep -qw "$DB"; then
    echo "La base de datos $DB ya existe."
    exit 1
fi

echo ">> Creating $DB"
docker compose run --rm web odoo -d "$DB" -i base --without-demo=True --stop-after-init

if [[ $SPAIN -eq 1 ]]; then
    # The country must be set before installing accounting: it selects the
    # Spanish chart of accounts.
    docker compose run --rm -T web odoo shell -d "$DB" --no-http <<'EOF'
env.ref("base.EUR").active = True
env.company.write({"country_id": env.ref("base.es").id, "currency_id": env.ref("base.EUR").id})
env.cr.commit()
EOF
    MODULES="l10n_es${MODULES:+,$MODULES}"
fi

if [[ -n "$MODULES" ]]; then
    echo ">> Installing $MODULES"
    docker compose run --rm web odoo -d "$DB" -i "$MODULES" --without-demo=True --stop-after-init
fi

echo ">> Loading Spanish"
docker compose run --rm web odoo i18n loadlang -d "$DB" -l es
docker compose run --rm -T web odoo shell -d "$DB" --no-http <<'EOF'
env.ref("base.user_admin").write({"lang": "es_ES", "tz": "Europe/Madrid"})
env.cr.commit()
EOF

docker compose up -d web
echo "Listo: http://localhost:8069 (base de datos $DB, usuario admin / admin)"
