#!/bin/sh

echo "EMPTY REQUEST"
curl http://127.0.0.1:9101/chunker?text=
echo ""
echo ""

echo "REQUEST WITH SINGLE UNKNOWN TAG"
curl http://127.0.0.1:9101/chunker?text=_
echo ""

echo "REQUEST WITH MULTIPLE TAGS AND FINAL UNKNOWN TAG"
curl http://127.0.0.1:9101/chunker?text=Vmip3s%0ATimsr%0ANcms-n%0ANp%0ANNN
echo ""

echo "REQUEST WITH MULTIPLE CORRECT TAGS"
curl http://127.0.0.1:9101/chunker?text=Vmip3s%0ATimsr%0ANcms-n%0ANp
echo ""
