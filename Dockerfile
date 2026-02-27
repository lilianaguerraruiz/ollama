FROM ollama/ollama:latest

# Wir brauchen curl + bash fürs Warten/Checks
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

# Startscript in den Container kopieren
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 11434

# WICHTIG:
# Wir überschreiben den Start (Entry) des Base-Images mit unserem Script,
# damit wir "serve + pull-if-missing" kontrollieren können.
ENTRYPOINT ["/start.sh"]
