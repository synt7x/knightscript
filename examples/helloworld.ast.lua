{
  body = {
    left = {
      name = {
        position = { 1, 7,
          file = "examples/helloworld.kns"
        },
        string = "greeting",
        type = "identifier"
      },
      right = {
        delimiter = '"',
        position = { 1, 18,
          file = "examples/helloworld.kns"
        },
        string = "Hello",
        type = "string"
      },
      scoped = true,
      type = "assignment"
    },
    right = {
      left = {
        name = {
          position = { 2, 7,
            file = "examples/helloworld.kns"
          },
          string = "where",
          type = "identifier"
        },
        right = {
          delimiter = '"',
          position = { 2, 15,
            file = "examples/helloworld.kns"
          },
          string = "world",
          type = "string"
        },
        scoped = true,
        type = "assignment"
      },
      right = {
        left = {
          args = { {
              left = {
                position = { 4, 7,
                  file = "examples/helloworld.kns"
                },
                string = "greeting",
                type = "identifier"
              },
              right = {
                left = {
                  delimiter = '"',
                  position = { 4, 18,
                    file = "examples/helloworld.kns"
                  },
                  string = ", ",
                  type = "string"
                },
                right = {
                  left = {
                    position = { 4, 25,
                      file = "examples/helloworld.kns"
                    },
                    string = "world",
                    type = "identifier"
                  },
                  right = {
                    delimiter = '"',
                    position = { 4, 33,
                      file = "examples/helloworld.kns"
                    },
                    string = "!",
                    type = "string"
                  },
                  type = "add"
                },
                type = "add"
              },
              type = "add"
            } },
          name = {
            position = { 4, 1,
              file = "examples/helloworld.kns"
            },
            string = "print",
            type = "identifier"
          },
          type = "call"
        },
        type = "expr"
      },
      type = "expr"
    },
    type = "expr"
  },
  comments = {},
  type = "program",
  version = "1.0.0-alpha"
}