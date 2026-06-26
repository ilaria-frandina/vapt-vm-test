# VA/PT VM — Infrastructure as Code

VM Kali Linux dedicata alle attività di Vulnerability Assessment / Penetration Test, definita come codice. Aggiorni un playbook Ansible e la pipeline ricostruisce l'immagine automaticamente.

## Stato attuale

Lo stack attivo è volutamente minimale: installa solo il necessario per avere **OpenVAS/Greenbone** funzionante. I playbook degli altri tool esistono in `playbooks/extra/` ma non sono attivi — si decommentano quando servono.

## Cosa contiene la VM (stack attivo)

| Playbook | Contenuto |
| -------- | --------- |
| `playbooks/system.yml` | Aggiornamento sistema, pacchetti base (`git`, `curl`, `python3`, `build-essential`, …) |
| `playbooks/desktop.yml` | `kali-desktop-xfce` + lightdm con autologin utente `vapt` |
| `playbooks/docker.yml` | Docker Engine CE (necessario per OpenVAS/Greenbone) |
| `playbooks/openvas.yml` | **Greenbone Community Edition** (OpenVAS) via Docker Compose, avviato automaticamente all'avvio |

Utente: `vapt` / `vapt` — **cambia la password prima di distribuire la VM**.

## Tool aggiuntivi disponibili (non attivi)

I playbook sotto `playbooks/extra/` sono pronti ma non inclusi nel build. Per attivarli, decommentare la riga corrispondente in `stacks/vapt-vm.yml`.

| Playbook | Strumenti |
| -------- | --------- |
| `extra/tools-network.yml` | `nmap`, `masscan`, `wireshark`, `tcpdump`, `socat`, `sslscan`, `hping3`, `ettercap`, `responder`, … |
| `extra/tools-web.yml` | `nikto`, `sqlmap`, `gobuster`, `ffuf`, `zaproxy`, `burpsuite`, `feroxbuster`, `wfuzz`, `wafw00f`, … |
| `extra/tools-exploitation.yml` | `metasploit-framework`, `exploitdb`, `netexec`, `impacket-scripts`, `evil-winrm`, `bloodhound` |
| `extra/tools-password.yml` | `hydra`, `john`, `hashcat`, `medusa`, `crunch`, `cewl` |
| `extra/tools-osint.yml` | `theharvester`, `recon-ng`, `dnsrecon`, `amass`, `maltego`, `subfinder`, `spiderfoot` |
| `extra/tools-go.yml` | Go 1.23.5 + `nuclei`, `httpx`, `katana` (compilati da sorgente) |
| `extra/wordlists.yml` | `wordlists` + `seclists` (~1.5 GB, pacchetti apt Kali) |

## Perché Kali Linux

Kali ha tutti i tool VA/PT già pacchettizzati e manutenuti dal team Offensive Security. Rispetto a una Debian base:
- Metasploit è un semplice `apt install` (niente repo Rapid7)
- `zaproxy`, `burpsuite`, `gobuster`, `ffuf` sono pacchetti apt
- `seclists` è un pacchetto apt (niente clone da GitHub da 1+ GB)

## Formati di output

| Formato | Destinatari | Builder Packer |
| ------- | ----------- | -------------- |
| `.qcow2` | Linux (GNOME Boxes, KVM, Proxmox, virt-manager) | QEMU |
| `.ova` | Windows / macOS (VirtualBox, VMware) | VirtualBox |

Entrambi costruiti dalla stessa definizione Packer + stesso stack Ansible.

## Pipeline CI/CD

```
release manuale → GitHub Actions (Linux + KVM)       → QCOW2
                → GitHub Actions (macOS + VirtualBox) → OVA

workflow_dispatch → scegli formato (qcow2 / ova / all) dalla tab Actions
```

Il workflow `.github/workflows/build.yml` **non parte automaticamente su push**. La build si avvia solo quando crei una release su GitHub o la lanci manualmente dalla tab Actions ("Run workflow").

**Secret richiesto nel repo GitHub:** `VM_PASSWORD` (la password dell'utente `vapt`).

## Struttura del progetto

```
.
├── packer/
│   ├── kali.pkr.hcl             # template Packer (sorgenti QEMU + VirtualBox)
│   ├── variables.pkr.hcl        # variabili (ISO, RAM, disco, utente, …)
│   └── http/
│       └── preseed.cfg          # installazione Kali non presidiata
├── .github/
│   └── workflows/
│       └── build.yml            # pipeline CI/CD
├── stacks/
│   └── vapt-vm.yml              # orchestratore: importa i playbook nell'ordine corretto
├── playbooks/
│   ├── system.yml               # ── stack attivo ──
│   ├── desktop.yml
│   ├── docker.yml
│   ├── openvas.yml
│   └── extra/                   # ── tool aggiuntivi (non attivi) ──
│       ├── tools-network.yml
│       ├── tools-web.yml
│       ├── tools-exploitation.yml
│       ├── tools-password.yml
│       ├── tools-osint.yml
│       ├── tools-go.yml
│       └── wordlists.yml
├── group_vars/
│   └── all/vars.yml             # variabili globali
├── ansible.cfg
├── inventory.ini
└── requirements.yml
```

## Attivare tool aggiuntivi

1. Aprire `stacks/vapt-vm.yml`
2. Decommentare il playbook desiderato
3. Push su `main` → poi avvia la build manualmente dalla tab Actions (o crea una release)

Per aggiungere un tool non ancora presente, trovare il pacchetto Kali (`apt search <tool>` o [pkg.kali.org](https://pkg.kali.org)) e aggiungerlo al playbook appropriato in `playbooks/extra/`.

## Requisiti per il build locale

- **Packer** >= 1.10.0
- **Ansible**
- Per QCOW2: Linux con **KVM** abilitato
- Per OVA: **VirtualBox** installato

```bash
# Inizializza i plugin Packer
packer init packer/kali.pkr.hcl

# Build QCOW2 (Linux con KVM)
packer build -only='qcow2.qemu.qcow2' packer/kali.pkr.hcl

# Build OVA (richiede VirtualBox)
packer build -only='ova.virtualbox-iso.ova' packer/kali.pkr.hcl

# Build entrambi
packer build packer/kali.pkr.hcl
```

Sovrascrivere variabili senza modificare file:
```bash
export PKR_VAR_vm_password="password-sicura"
export PKR_VAR_vm_version="2.0.0"
packer build packer/kali.pkr.hcl
```

## Provisioning manuale su VM in esecuzione

```bash
# Riesegui l'intero stack
ansible-playbook stacks/vapt-vm.yml -e target=vapt-vm

# Applica un singolo playbook extra (es. dopo aver attivato tools-web)
ansible-playbook playbooks/extra/tools-web.yml -e target=vapt-vm
```

## Greenbone / OpenVAS

Dopo il primo avvio, Greenbone CE si avvia automaticamente. Interfaccia web su `http://localhost:9392`.

Primo avvio — recupera la password admin generata:
```bash
docker compose -f /opt/greenbone/docker-compose.yml exec gvmd \
  gvmd --get-users --verbose
```

Cambia la password admin:
```bash
docker compose -f /opt/greenbone/docker-compose.yml exec gvmd \
  gvmd --user=admin --new-password=nuova-password
```

## Aggiornare l'ISO Kali

Aggiorna `packer/variables.pkr.hcl`:
```hcl
variable "iso_url" {
  default = "https://cdimage.kali.org/kali-YYYY.N/kali-linux-YYYY.N-installer-amd64.iso"
}
variable "iso_checksum" {
  default = "file:https://cdimage.kali.org/kali-YYYY.N/SHA256SUMS"
}
```
