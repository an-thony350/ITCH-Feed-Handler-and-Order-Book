"""
- Turns the ITCH feed into a stream of NormalisedEvents

- Split into:
    - Record reader that walks the BinaryFILE
    - Decoder that given one message's bytes, decodes it into a NormalisedEvent
"""