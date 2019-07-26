# Aether & Gather

## Who is Who

**Aether Kernel** is the core app.

- It contains all the relevant data:
  - The list of Projects (AKA Surveys).
  - The list of instructions (AKA Mappings) that transforms the received submissions into entities.
  - The submissions and the extracted entities.

**Aether UI** is the "instructions" builder UI.

- Starting from an input sample, it helps creating the instructions (AKA Pipelines and Contracts) to extract and transform the relevant data (AKA entities).

**Aether ODK** is the module that communicates with ODK Collect.

- It contains the xForms and the surveyors.
- For each xForm it generates an "identity" mapping that for each received submission extracts an entity equal to it (this kind of entities are the ones showed in Gather).
- It implements the API that ODK Collect needs to fetch the xForms and media files and, to submit data.
- It receives the submissions from ODK Collect and redirects them to Aether Kernel along with the linked attachments.

**Gather** is basically the data UI.

- So far, it keeps little data only related to the frontend settings.
- It helps creating the Surveys/Projects, xForms and Surveyors and distributing them to the aether apps.
- It fetches the identity entities from Kernel and displays them in a table.

## Data model schema

```text
Kernel

+------------------+     +------------------+     +------------------+     +------------------+
| Project          |<----| MappingSet       |<----| Submission       |<----| Attachment       |
+==================+     +==================+     +==================+     +==================+
                                  ^                        ^
                                  |                        |
                         +------------------+     +------------------+
                         | Mapping          |<----| Entity           |
                         +==================+     +==================+

UI

+------------------+     +------------------+     +------------------+
| Project          |<----| Pipeline         |<----| Contract         |
+==================+     +==================+     +==================+

ODK

+------------------+     +------------------+     +------------------+
| Project          |<----| XForm            |<----| MediaFile        |
+==================+     +==================+     +==================+

Gather

+------------------+
| Survey           |
+==================+

```

Correspondence table:

| App       | Set of similar inputs | Input sample | Set of transform instructions |
| --------- | --------------------- | ------------ | ----------------------------- |
| Kernel    | Project               | MappingSet   | Mapping                       |
| Kernel UI | Project               | Pipeline     | Contract                      |
| ODK       | Project               | xForm        | XForm (identity instructions) |
| Gather    | Survey                | ---          | ---                           |


## How to communicate with Aether via REST API

The way to authenticate in Aether and Gather using Kong as Gateway service is to include the `X-Oauth-Token` value in all the requests.

```bash
curl -L -H "Authorization: Bearer $X_OAUTH_TOKEN" $url
```

The URLs to access Aether are:

- Aether Kernel: `${BASE_HOST}/{realm}/kernel`
- Aether ODK: `${BASE_HOST}/{realm}/odk`

Using

- `BASE_HOST=http://aether.local`
- `realm=ehealth`

then:

- Aether Kernel: http://aether.local/ehealth/kernel
- Aether ODK: http://aether.local/ehealth/odk


### List of items

The REST API implements a page number pagination.

http://aether.local/ehealth/kernel/projects.json?page_size=10&page=5

```json
{
  "count": 1023,
  "next": "http://aether.local/ehealth/kernel/projects.json?page_size=10&page=6",
  "previous": "http://aether.local/ehealth/kernel/projects.json?page_size=10&page=4",
  "results": [
    …
  ]
}
```

The default `page_size` is `10`.

To reduce the size of the response there are also available two parameters:
- `field`, comma-separate list of field names to include in the response.
- `omit`, comma-separate list of field names to omit in the response.


http://aether.local/ehealth/kernel/projects.json?fields=id,name

```json
{
  …,
  "results": [
    {
      "id": "dcb361e7-643e-4761-84b6-0f011e2a6a9b",
      "name": "Project 1"
    },
    …
  ]
}
```

http://aether.local/ehealth/kernel/mappingsets.json?omit=created,modified

These two parameters are also available to GET a single item.

### Useful URLs

#### List of projects (paginated)

- `http://aether.local/ehealth/kernel/projects.json`
- `http://aether.local/ehealth/odk/projects.json`

  This request is very expensive because it also returns the linked xForms and surveyors.
  It's convenient to reduce the size of the response with `omit=xforms,surveyors`.

There is a one to one relation between Kernel and ODK projects sharing the same `id`.

#### List of xForms (paginated)

http://aether.local/ehealth/odk/xforms.json?fields=id,title,version,kernel_id,project

The ODK xForms produce a pair of MappingSet and Mapping (with the same `id`) in kernel.
The xForm model has a field named `kernel_id` to identify them.

#### List of xForms by project (NOT paginated)

`http://aether.local/ehealth/odk/projects/<<project_id>>.json?fields=id,name,xforms`

#### List of submissions by project (paginated)

`http://aether.local/ehealth/kernel/submissions.json?fields=id,payload&project=<<project_id>>`

#### List of submissions by xForm (paginated)

`http://aether.local/ehealth/kernel/submissions.json?fields=id,payload&mappingset=<<xform_kernel_id>>`

#### List of entities by project (paginated)

`http://aether.local/ehealth/kernel/entities.json?fields=id,payload&project=<<project_id>>`

#### List of entities by xForm (paginated)

`http://aether.local/ehealth/kernel/entities.json?fields=id,payload&mapping=<<xform_kernel_id>>`
