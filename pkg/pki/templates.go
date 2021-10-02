package pki

import (
	"crypto/x509"
	"crypto/x509/pkix"
	"github.com/tsaarni/x500dn"
	"time"
)

func ValidDays(days int) func (certificate *x509.Certificate) {
	return func(certificate *x509.Certificate) {
		certificate.NotBefore = time.Now()
		certificate.NotAfter = time.Now().AddDate(0,0,days)
	}
}

func CA() func (certificate *x509.Certificate) {
	return func(certificate *x509.Certificate) {
		certificate.IsCA = true
		certificate.BasicConstraintsValid = true
		certificate.KeyUsage = x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign | x509.KeyUsageCRLSign
	}
}

func Issuer(name string) func (certificate *x509.Certificate, error) {
	n, err := ParseDN(name)
	if err != nil {
		return err
	}
	return func (certificate *x509.Certificate) {
		certificate.Issuer = n
	}
}

func Subject(name string) func (certificate *x509.Certificate, error) {
	n, err := ParseDN(name)
	if err != nil {
		return err
	}
	return func (certificate *x509.Certificate) {
		certificate.Subject = n
	}
}
