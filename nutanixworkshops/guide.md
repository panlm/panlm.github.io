

git clone workshop to local
change Makefile

BUILDDIR      = ../../panlm.github.io/lab/partnercalmworkshop

change conf.py, add sphinxtogithub to extensions

extensions = ['sphinx.ext.todo',
    'sphinx.ext.ifconfig',
    'sphinxcontrib.fulltoc',
    'sphinx_fontawesome',
    'sphinxtogithub']

as README.md install packages

pip install sphinxcontrib-fulltoc==1.2.0
pip install sphinx-bootstrap-theme==0.6.0
pip install sphinx_fontawesome

install sphinxtogithub

pip install sphinxtogithub

make html

commit panlm.github.io repo and push it

check website panlm.github.io/lab/partnercalmworkshop

refer
http://lucasbardella.com/blog/2010/02/hosting-your-sphinx-docs-in-github
https://daler.github.io/sphinxdoc-test/includeme.html



