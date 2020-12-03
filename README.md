# certbot-hooks
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/Adspectus/certbot-hooks?style=flat-square&label=Version)](https://github.com/Adspectus/certbot-hooks/releases)
[![GitHub issues](https://img.shields.io/github/issues/Adspectus/certbot-hooks?style=flat-square&label=Issues)](https://github.com/Adspectus/certbot-hooks/issues)
[![GitHub license](https://img.shields.io/github/license/Adspectus/certbot-hooks?style=flat-square&label=License)](https://github.com/Adspectus/certbot-hooks/blob/main/LICENSE)


The __certbot-hooks__ are two scripts which can be used as pre- and post-validation hook for certbot when run in manual mode to validate domains by DNS challenge via deSEC. It is based upon the `hook.sh` script provided by Peter Thomassen and Nils Wisiol to allow dedyn.io DNS challenge validation (see [Credits](#credits) below).

The main differences to the script provided by the authors above is that it is not limited to a dedyn.io domain and that the authorization token can be provided for single domains, allowing certbot to validate domains owned by different accounts in deSEC. Moreover, the single script has been divided into two, allowing easier exchange of either the pre- or post-validation hook.

See [Pre and Post Validation Hooks](https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks) in the certbot user guide and [TLS Certificate with Let’s Encrypt](https://desec.readthedocs.io/en/latest/dyndns/lets-encrypt.html) in the deSEC docs for further reference.

## Contents

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [Credits](#credits)
* [License](#license)

## Prerequisites

These scripts are intended to be used for the certbot pre- and post validation hooks, which are supplied to certbot with the `--manual-auth-hook` and `--manual-cleanup-hook` command line options. Any other program for the creation or renewal of certificates doing a DNS validation could use these scripts in a similar way. The program just have to pass the environment variables `CERTBOT_DOMAIN` (the domain being authenticated) and `CERTBOT_VALIDATION` (the validation string) to the scripts.

Further prerequisites:

* curl
* jq

## Installation

1. Copy all files to a single location, i.e. `/etc/letsencrypt`. Any directory is ok, but the files `DOMAIN.desecauth` and `desec.conf` have to be placed into the same directory as the scripts `desec_auth_hook.sh` and `desec_cleanup_hook.sh`. While the scripts should be executable, the `DOMAIN.desecauth` file(s) should be chmod 600, as they contain the token used to authenticate gainst the deSEC API.

2. Rename the file `DOMAIN.desecauth` to match the domain part of the certificate which shold be created or renewed by DNS challenge, i.e. `example.com.desecauth` for the `example.com` domain. If there are multiple domains to be created or renewed, you need multiple files with matching names.

3. Check the values in the file `desec.conf`. You could change the sleep timer and the TTL. If you do not provide a TTL (`TTL=`), it will be read from deSEC.

## Usage

Provide the scripts to certbot with the mentioned command line options, i.e.

```
certbot --manual-auth-hook=/etc/letsencrypt/desec_auth_hook.sh --manual-cleanup-hook=/etc/letsencrypt/desec_cleanup_hook.sh ...
```

## Credits

Peter Thomassen and Nils Wisiol for the [Hook for certbot DNS challenge automatization](https://github.com/desec-utils/certbot-hook).
## License

[MIT License](LICENSE)
