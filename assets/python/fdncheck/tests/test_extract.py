# SPDX-License-Identifier: Apache-2.0
from conftest import snap

from fdncheck.extract.links import page_observations


def methods(snapshot):
    return {o.method: o.value for o in page_observations(snapshot)}


def test_title_is_normalized():
    assert methods(snap("https://a.org/", body=b"<html><title>\n  Acme \n Home</title></html>")) == {
        "page:title": "Acme Home"
    }


def test_script_only_page_needs_javascript():
    body = (
        b"<html><head><title>App</title><script src='app.js'></script></head><body><div id='root'></div></body></html>"
    )
    assert methods(snap("https://a.org/", body=body))["page:needs-javascript"] is True


def test_page_with_text_does_not_need_javascript():
    body = b"<html><body><script>1</script><p>" + b"Real content here. " * 20 + b"</p></body></html>"
    assert "page:needs-javascript" not in methods(snap("https://a.org/", body=body))


def test_non_html_and_errors_give_nothing():
    assert page_observations(snap("https://a.org/x.pdf", body=b"%PDF-1.7", content_type="application/pdf")) == []
    assert page_observations(snap("https://a.org/", status=0, body=b"", error="timeout")) == []
