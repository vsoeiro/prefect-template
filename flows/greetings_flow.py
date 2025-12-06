from prefect import flow, task


@task
def build_greeting(name: str) -> str:
    return f"Hello, {name}!"


@flow
def greetings_flow(name: str = "world") -> str:
    return build_greeting(name)


if __name__ == "__main__":
    greetings_flow()
