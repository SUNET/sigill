package pki

import (
	"crypto"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"github.com/ThalesIgnite/crypto11"
	"math/big"
	"os"
)


type CertificationAuthority struct {
	Session *crypto11.Context
	PrivateKey crypto.Signer
	CACert *x509.Certificate
}

func randSerial() *big.Int {
	//Max random value, a 130-bits integer, i.e 2^130 - 1
	max := new(big.Int)
	max.Exp(big.NewInt(2), big.NewInt(130), nil).Sub(max, big.NewInt(1))

	//Generate cryptographically strong pseudo-random between 0 - max
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		//error handling
	}
	return n
}

func NewCertificationAuthority(id []byte, label []byte, isRoot bool) (*CertificationAuthority, error) {
	session, err := crypto11.ConfigureFromFile(os.Getenv("PKCS11_MODULE"))
	if err != nil {
		return nil, err
	}

	signer, err := session.FindKeyPair(id, label)
	if err != nil {
		return nil, err
	}

	caCert, err := session.FindCertificate(nil, label, nil)
	if err != nil  && !isRoot {
		return nil, err
	}

	return &CertificationAuthority{
		Session: session,
		PrivateKey: signer,
		CACert: caCert,
	}, nil
}

type T func(certificate *x509.Certificate)

func (ca *CertificationAuthority) Issue(Templates []T) ([]byte, error){
	cert := &x509.Certificate{SerialNumber: randSerial(), IsCA: false, BasicConstraintsValid: false}
	for _,t := range Templates {
		t(cert)
	}
	certBytes, err := x509.CreateCertificate(rand.Reader,cert,ca.CACert,ca.PrivateKey.Public(), ca.PrivateKey)
	return certBytes, err
}

func (ca *CertificationAuthority) CreateRootCA(days int, name pkix.Name) ([]byte, error) {
	return ca.Issue([]T {
		ValidDays(days),
		CA(),
		Issuer(name),
		Subject(name),
	})
}