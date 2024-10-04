# MishkaChelekom

Mishka Chelekom is a library offering various templates for components in **Phoenix** and **Phoenix LiveView** [(Phoenix UI kit and components)](https://mishka.life/chelekom).
This means you can generate any component listed in this project using a `CLI` command with customizable options.

> For example, you can create a component with an `info` color and a "shadow" variant without having any unnecessary code clutter.

If you want to add another variant in the future, the project is powered by the [**Igniter**](https://github.com/ash-project/igniter) library, which makes it easy to update the previous code seamlessly.

You will only use this library in your `development` environment, and it will not have any presence in production.

## Installation

```elixir
def deps do
  [
    {:mishka_chelekom, "~> 0.0.1", only: :dev}
  ]
end
```

Generate all components inside the `components` directory of your Phoenix project.

### Creating a Component (Example: Creating an Alert)

```bash
mix mishka.ui.gen.component alert --color info --variant default
mix mishka.ui.gen.component alert
```

### Generating All Components

```bash
mix mishka.ui.gen.components
```

### Generating All Components with an Import File

```bash
mix mishka.ui.gen.components --import --yes
```

> This command creates all the components along with a file where all the components are imported.

### Optimized for Minimal Dependencies

This project ensures optimal performance by minimizing dependencies and leveraging the advanced features of **Tailwind CSS**.

### Links:

- Project Page: https://mishka.life/chelekom
- Project Documentation: https://mishka.life/chelekom/docs
- Created components list: [Heex file and configs](https://github.com/mishka-group/mishka_chelekom/tree/master/priv/templates/components)

---

### Our stacks:

1. [Elixir](https://github.com/elixir-lang/elixir)
2. [Phoenix](https://github.com/phoenixframework/phoenix)
3. [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)
4. [Tailwind CSS](https://github.com/tailwindlabs/tailwindcss)
5. Pure JavaScript
