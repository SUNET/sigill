package pki

import (
	"github.com/ThalesIgnite/crypto11"
	"crypto"
	"crypto/x509"
)


type CertificationAuthority struct {
	Token crypto11.Context
	PrivateKey crypto.Signer
	CACert x509.Certificate
	Templates map[string]x509.Certificate
}