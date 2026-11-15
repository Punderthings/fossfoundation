# SPDX-License-Identifier: Apache-2.0
"""fdncheck: check _foundations records against each foundation's own website.

The package has five layers, and each one does one kind of work:

- ``fetch``: web scraping; the only code that uses the network.
- ``extract``: pure functions from a saved page (a ``Snapshot``) to observed values.
- ``records``: our data and schema: loading records and the field catalog.
- ``detect``: update detection; compares a record with what was observed.
- ``propose``: output; the minimal edit to a record, the report and the commit message.

``check.run_check`` ties them together for one foundation.
"""

__version__ = "0.1.0"
TOOL = f"fdncheck/{__version__}"
