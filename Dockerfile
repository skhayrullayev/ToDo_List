FROM python:3.10 as builder

WORKDIR /usr/src/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update
RUN apt-get upgrade -y && apt-get -y install postgresql gcc python3-dev musl-dev

RUN pip install --upgrade pip

COPY . .


COPY ./requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


FROM python:3.10

RUN mkdir -p /home/app

RUN groupadd todo_group
RUN useradd -m -g todo_group todo_user -p password

RUN usermod -aG todo_group todo_user

ENV HOME=/home/app
ENV APP_HOME=/home/app/todo_app
RUN mkdir $APP_HOME
RUN mkdir $APP_HOME/staticfiles

WORKDIR $APP_HOME

RUN apt-get update \
    && apt-get install netcat-openbsd -y

COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .

RUN pip install --no-cache /wheels/*

COPY ./entrypoint.prod.sh $APP_HOME

COPY . $APP_HOME

RUN chown -R todo_user:todo_group $APP_HOME
RUN chmod +x /home/app/todo_app/entrypoint.prod.sh

USER todo_user

ENTRYPOINT ["/home/app/todo_app/entrypoint.prod.sh"]