https://github.com/typicode/json-server

json-server [options] <source>

Options:
  --config, -c       Path to config file           [default: "json-server.json"]
  --port, -p         Set port                                    [default: 3000]
  --host, -H         Set host                             [default: "localhost"]
  --watch, -w        Watch file(s)                                     [boolean]
  --routes, -r       Path to routes file
  --middlewares, -m  Paths to middleware files                           [array]
  --static, -s       Set static files directory
  --read-only, --ro  Allow only GET requests                           [boolean]
  --no-cors, --nc    Disable Cross-Origin Resource Sharing             [boolean]
  --no-gzip, --ng    Disable GZIP Content-Encoding                     [boolean]
  --snapshots, -S    Set snapshots directory                      [default: "."]
  --delay, -d        Add delay to responses (ms)
  --id, -i           Set database id property (e.g. _id)         [default: "id"]
  --foreignKeySuffix, --fks  Set foreign key suffix, (e.g. _id as in post_id)
                                                                 [default: "Id"]
  --quiet, -q        Suppress log messages from output                 [boolean]
  --help, -h         Show help                                         [boolean]
  --version, -v      Show version number                               [boolean]


curl 127.0.0.1:8080/posts
curl 127.0.0.1:8080/comments/
curl 127.0.0.1:8080/comments/1
curl -XGET 127.0.0.1:8080/posts?_embed=comments
curl -XGET 127.0.0.1:8080/comments?_embed=replies
curl -H 'Content-Type: application/json' -XPOST "127.0.0.1:8080/users" -d '{"id": "5", "nom":"patrick", "ville": "nantes"}'
curl -XDELETE "127.0.0.1:8080/users/4"
